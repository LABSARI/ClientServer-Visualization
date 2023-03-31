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

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildDaoLayer [

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'Dao: ' , daoLayer size asString , ' classes';
		  gapSize: 80;
		  addAll: (self entitiesOf: daoLayer);
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

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'Service: ' , serviceLayer size asString , ' classes';
		  gapSize: 80;
		  addAll: (self entitiesOf: serviceLayer);
		  yourself
]

{ #category : #building }
MiMultiLlayerVisualizationModel >> buildUCLayer [

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'UC: ' , (serverLayers at: 1) size asString , ' classes';
		  gapSize: 80;
		  addAll: (self entitiesOf: (serverLayers at: 1));
		  yourself
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
	serviceLayer := Set new
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

	(self serverLayers at: 1) addAll: remoteServer subclassHierarchy
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
	self addDependenciesToServicesAndTag
]

{ #category : #accessing }
MiMultiLlayerVisualizationModel >> mooseModel: aMooseModel [

	mooseModel := aMooseModel
]
