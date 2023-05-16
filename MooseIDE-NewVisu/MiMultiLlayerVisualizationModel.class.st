Class {
	#name : #MiMultiLlayerVisualizationModel,
	#superclass : #MiLayerVisualizationModel,
	#instVars : [
		'daoTag',
		'implAndIntViolation',
		'serviceTag',
		'serviceLayer',
		'daoLayer'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addDependenciesFrom: sourcesLayer to: targetsLayer execute: aBlock [

	sourcesLayer do: [ :class | 
		(self classDependenciesFor: class) do: [ :dc | 
			(targetsLayer includes: dc) ifTrue: [
				self addDependency: dc in: incomingCache for: class.
				self addDependency: class in: outgoingCache for: dc.
				aBlock value: class value: dc ] ] ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addDependenciesToDaoAndTag [

	self
		addDependenciesFrom: (self serverLayers at: 1)
		to: daoLayer
		execute: [ :impl :dao | 
			dao tagWith: daoTag.
			impl tagWith: implAndIntViolation ].

	daoLayer do: [ :class | 
		(self classDependenciesFor: class) do: [ :d | 
			(serviceLayer includes: d) ifTrue: [ 
				self addDependency: d in: incomingCache for: class.
				self addDependency: class in: outgoingCache for: d ] ] ].


	serviceLayer do: [ :class | 
		(self classDependenciesFor: class) do: [ :d | 
			((self serverLayers at: 1) includes: d) ifTrue: [ 
				self addDependency: d in: incomingCache for: class.
				self addDependency: class in: outgoingCache for: d ] ] ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addDependenciesToServicesAndTag [

	self
		addDependenciesFrom: (self serverLayers at: 1)
		to: serviceLayer
		execute: [ :impl :service | 
			(service hasTag: serviceTag) ifFalse: [ 
				service tagWith: serviceTag ] ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addLayer [


	| allNewSClasses |
	1halt.
	allNewSClasses := self addCacheServerDependencies.
	serverLayers add: allNewSClasses.
	self setServerClasses.

	index := index + 1
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addLayerToServerFromLevel: level [

	| hasAddedSomething newDict currentDict |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := self serverLayers at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #dao ifTrue: [ 
				| n |
				n := self dao at: d.
				d tagWith: daoTag].
			response = #service ifTrue: [ 
				hNode dependencyTo: (self eServices at: d) ].
			response = #free ifTrue: [ 
				"| newNode |
				newNode := self buildNodeFromEntity: d.
				hNode dependencyTo: newNode.
				newDict at: d put: newNode.
				hasAddedSomething := true" ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		self serverLayers add: newDict.
		^ true ].
	^ false
]

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildDaoLayer [
	| daosToDisplay |
	daosToDisplay := displayStrategy fetchViolatingDaos.
	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'Dao: ' , daosToDisplay size asString , ' classes';
		  gapSize: 80;
		  addAll: (self entitiesOf: daosToDisplay);
		  yourself
]

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildDescription [

	(description := MiLVHorizontalBoxNode new)
		withoutBorder;
		gapSize: 90;
		add: self buildUCLayer;
		add: self buildServiceLayer;
		add: self buildDaoLayer.
	^ description
]

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildServiceLayer [

	| serviceToDisplay |
	serviceToDisplay := displayStrategy fetchViolatingServices.
	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'Service: ' , serviceToDisplay size asString , ' classes';
		  gapSize: 80;
		  addAll: (self entitiesOf: serviceToDisplay);
		  yourself
]

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildUCLayer [

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'UC';
		  gapSize: 80;
		  addAll: self buildUCLayers;
		  yourself
]

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildUCLayers [

	^ self serverLayers collect: [ :layer | 
		  MiLVFlowBoxNode new
			  dashedBorder;
			  addAll: (self entitiesOf: layer);
			  yourself ]
]

{ #category : #partitioning }
MiMultiLlayerVisualizationModel >> checkIsImplementationOrService: aClass [
	^ self checkIsImplementation: aClass 
]

{ #category : #queries }
MiMultiLlayerVisualizationModel >> dao [

	| sa |
	sa := (((FQStringQuery
		         property: #name
		         comparator: #=
		         valueToCompare: 'DaoAbstract') runOn: mooseModel allClasses) 
		       reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.

	^ sa subclassHierarchy
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> daoLayer [

	^ daoLayer
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> daoLayer: anObject [

	daoLayer := anObject
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> daoTag [

	^ daoTag
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> daoTag: anObject [

	daoTag := anObject
]

{ #category : #queries }
MiMultiLlayerVisualizationModel >> eServices [

	| sa |
	sa := (((FQStringQuery
		         property: #name
		         comparator: #=
		         valueToCompare: 'ServiceAbstract') runOn:
		        mooseModel allClasses) reject: [ :c | 
		       c subclassHierarchy isEmpty ]) anyOne.

	^ sa subclassHierarchy
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> initialize [

	super initialize.
	daoLayer := Set new.
	serviceLayer := Set new.
	displayStrategy := MiFilterMultiLayerViolationStrategy new
		                   visualizationModel: self;
		                   yourself
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> initializeFirstServerLayer [

	| remoteServer |
	
	self serverLayers add: Dictionary new.
	remoteServer := ((FQStringQuery
		                  property: #name
		                  comparator: #=
		                  valueToCompare: 'RemoteServer') runOn:
		                 mooseModel allClasses) anyOne.
	self serverLayers at: 1 put: remoteServer subclassHierarchy
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> initializeOtherLayers [

	daoTag := (self mooseModel tagNamed: 'daoViolation')
		          color: (Color fromHexString: 'B2182B');
		          yourself.
	implAndIntViolation := self mooseModel tagNamed:
		                       'implAndIntViolation'.
	serviceTag := (self mooseModel tagNamed: 'serviceNoViolation')
		              color: (Color fromHexString: 'EF8A62');
		              yourself.
	self eServices do: [ :c | serviceLayer add: c ].
	self dao do: [ :c | daoLayer add: c ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> initializePartitioning [

	self initializeFirstServerLayer.
	self initializeOtherLayers.
	self addDependenciesToDaoAndTag.
	self addDependenciesToServicesAndTag.
	index := 1
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> mooseModel: aMooseModel [

	mooseModel := aMooseModel
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> serviceLayer [

	^ serviceLayer
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> serviceLayer: anObject [

	serviceLayer := anObject
]
