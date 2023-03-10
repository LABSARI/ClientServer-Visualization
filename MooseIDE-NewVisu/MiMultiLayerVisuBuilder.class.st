Class {
	#name : #MiMultiLayerVisuBuilder,
	#superclass : #MiNewVisuBuilder,
	#instVars : [
		'daoDict',
		'serviceDict',
		'daoTag',
		'serviceTag',
		'implAndIntViolation'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #initialization }
MiMultiLayerVisuBuilder >> addDependenciesToDaoAndTag [

	self
		addDependenciesFrom: (serverDicts at: 1)
		to: daoDict
		execute: [ :impl :dao | 
			dao tagWith: daoTag.
			impl tagWith: implAndIntViolation.
			pNodes add: (daoDict at: dao) ]
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> addDependenciesToServicesAndTag [


	self
		addDependenciesFrom: (serverDicts at: 1)
		to: serviceDict
		execute: [ :impl :service | 
		(service hasTag: serviceTag) ifFalse: [ service tagWith: serviceTag ] ]
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> addLayerToClientFromLevel: level [

	| newDict currentDict hasAddedSomething |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := clientDicts at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #server ifTrue: [ 
				(self indexOf: d in: serverDicts) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d ToSharedfrom: serverDicts) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ].
		(self classDependantsFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #free ifTrue: [ 
				| newNode |
				newNode := self buildNodeFromEntity: d.
				newNode dependencyTo: hNode.
				newDict at: d put: newNode.
				hasAddedSomething := true ].
			response = #client ifTrue: [ 
				newDict at: d ifPresent: [ :n | n dependencyTo: hNode ] ].
			response = #server ifTrue: [ 
				(self indexOf: d in: serverDicts) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d ToSharedfrom: serverDicts) ] ].
			response = #shared ifTrue: [ "(sharedDict at: d) dependencyTo: hNode"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		clientDicts add: newDict.
		^ true ].
	^ false
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> addLayerToServerFromLevel: level [

	| hasAddedSomething newDict currentDict |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := serverDicts at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #dao ifTrue: [ 
				| n |
				n := daoDict at: d.
				hNode dependencyTo: n.
				d tagWith: daoTag.
				pNodes add: n ].
			response = #service ifTrue: [ 
				hNode dependencyTo: (serviceDict at: d) ].
			response = #free ifTrue: [ 
				| newNode |
				newNode := self buildNodeFromEntity: d.
				hNode dependencyTo: newNode.
				newDict at: d put: newNode.
				hasAddedSomething := true ].
			response = #client ifTrue: [ 
				(self indexOf: d in: clientDicts) > 1 ifTrue: [ 
					level = 1 ifTrue: [ class tagWith: implAndIntViolation ].
					hNode dependencyTo: (self moveClass: d ToSharedfrom: clientDicts) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		serverDicts add: newDict.
		^ true ].
	^ false
]

{ #category : #building }
MiMultiLayerVisuBuilder >> buildDescription [

	| serverLayouts clientLayouts description |
	serverLayouts := self buildLayoutsFor: serverDicts reversed: false.
	clientLayouts := self buildLayoutsFor: clientDicts reversed: true.




	(description := MiNVVerticalLayoutNode new)
		gapSize: 90;
		add: (MiNVBoxNode new
				 name:
					 'Transverse DTOs: ' , sharedDict values size asString
					 , ' classes';
				 layout: (MiNVFlowLayoutNode new
						  gapSize: 80;
						  addAll: ({ (HNode new
								    name: 'DTOs';
								    rawModel: 'DTOs';
								    addAll: (self commonPackagesFor: sharedDict values);
								    collapse;
								    yourself) } collect: [ :c | 
								   MiNVElement new
									   model: c;
									   yourself ]);
						  yourself);
				 yourself);
		add: (MiNVHorizontalLayoutNode new
				 gapSize: 90;
				 add: (MiNVBoxNode new
						  name: 'Client';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: clientLayouts;
								   yourself);
						  yourself);
				 add: (MiNVBoxNode new
						  name: 'Server';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: serverLayouts;
								   yourself);
						  yourself);
				 yourself);
		add: (MiNVBoxNode new
				 name:
					 'Purgatory: ' , purgatoryDict values size asString , ' classes';
				 layout: (MiNVFlowLayoutNode new
						  addAll:
							  ((self commonPackagesFor: purgatoryDict values) collect: [ :c | 
									   MiNVElement new
										   model: c;
										   yourself ]);
						  yourself);
				 yourself).
	description := MiNVBoxNode new
		               name: 'UC';
		               layout: description;
		               yourself.
	description := MiNVHorizontalLayoutNode new
		               gapSize: 90;
		               add: description;
		               add: (MiNVBoxNode new
				                name:
					                'Services: ' , serviceDict values size asString
					                , ' classes';
				                layout: (MiNVFlowLayoutNode new
						                 addAll:
							                 ((self commonPackagesFor: serviceDict values) 
								                  collect: [ :c | 
									                  MiNVElement new
										                  model: c;
										                  yourself ]);
						                 yourself);
				                yourself);
		               add: (MiNVBoxNode new
				                name:
					                'DAO: ' , daoDict values size asString
					                , ' classes';
				                layout: (MiNVFlowLayoutNode new
						                 addAll:
							                 ((self commonPackagesFor: daoDict values) 
								                  collect: [ :c | 
									                  MiNVElement new
										                  model: c;
										                  yourself ]);
						                 yourself);
				                yourself);
		               yourself.
	^ description
]

{ #category : #building }
MiMultiLayerVisuBuilder >> buildLayoutsFor: dicts reversed: reverse [

	| layouts |
	layouts := dicts withIndexCollect: [ :d :i | 
		           | box layout entities filtered |
		           i = 1
			           ifTrue: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.

				           layout := MiNVVerticalLayoutNode new.
				           box := MiNVBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself.
				           entities := filtered sort: [ :a :b | a name < b name ] ]
			           ifFalse: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.
				           layout := MiNVFlowLayoutNode new.
				           entities := self commonPackagesFor: filtered.
				           box := MiNVBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself ].
		           layout addAll: (entities collect: [ :c | 
				            MiNVElement new
					            model: c;
					            yourself ]).
		           box ].
	^ reverse
		  ifTrue: [ layouts reversed ]
		  ifFalse: [ layouts ]
]

{ #category : #partitioning }
MiMultiLayerVisuBuilder >> classAlreadyPresent: aClass [

	| response |
	response := super classAlreadyPresent: aClass.
	response = #free ifFalse: [ ^ response ].
	daoDict at: aClass ifPresent: [ ^ #dao ].
	serviceDict at: aClass ifPresent: [ ^ #service ].
	^ #free
]

{ #category : #private }
MiMultiLayerVisuBuilder >> colorFor: node [

	| entity |
	node color ifNotNil: [ :c | ^ c ].


	entity := node rawModel.
	entity isMooseObject ifFalse: [ ^ Color fromHexString: 'E0E0E0' ].
	(entity isPackage and: [ self packageContainsDaoViolation: node ]) 
		ifTrue: [ ^ daoTag color ].
	(entity isPackage and: [ 
		 (serviceDict includesKey: node children anyOne rawModel) and: [ 
			 self packageContainsServiceViolation: node ] ]) ifTrue: [ 
		^ serviceTag color ].

	(entity isType and: [ 
		 (sharedDict includesKey: entity) and: [ self nodeIsShared: node ] ]) 
		ifTrue: [ ^ Color fromHexString: '9970AB' ].

	(entity isPackage and: [ 
		 (sharedDict includesKey: node children anyOne rawModel) and: [ 
			 node children anySatisfy: [ :child | self nodeIsShared: child ] ] ]) 
		ifTrue: [ ^ Color fromHexString: '9970AB' ].

	(entity isPackage and: [ self packagePresentInBothSides: entity ]) 
		ifTrue: [ ^ Color fromHexString: 'DFC27D' ].


	"mapModel shouldColor ifFalse: [ ^ Color fromHexString: '7FC6F6' ].

	^ (self entityIsInClientPackage: entity)
		  ifTrue: [ Color fromHexString: '7FC6F6' ]
		  ifFalse: [ Color fromHexString: 'FFABA3' ]"
	^ Color fromHexString: 'E0E0E0'
]

{ #category : #building }
MiMultiLayerVisuBuilder >> entitiesWithViolationFrom: aDict [

	| v |
	v := OrderedCollection new.
	daoDict valuesDo: [ :hn | 
		hn dependencies do: [ :d | 
			| c |
			c := d from = hn rawModel
				     ifTrue: [ d to ]
				     ifFalse: [ d from ].
			aDict at: c rawModel ifPresent: [ :n | v add: n ] ] ].
	purgatoryDict valuesDo: [ :hn | 
		hn dependencies do: [ :d | 
			| c |
			c := d from = hn rawModel
				     ifTrue: [ d to ]
				     ifFalse: [ d from ].
			aDict at: c rawModel ifPresent: [ :n | v add: n ] ] ].
	^ v asSet
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initialize [

	super initialize.
	daoDict := Dictionary new.
	serviceDict := Dictionary new
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initializeFirstServerLayer [

	| remoteServer |
	serverDicts add: Dictionary new.
	remoteServer := ((FQStringQuery
		                  property: #name
		                  comparator: #=
		                  valueToCompare: 'RemoteServer') runOn:
		                 self services anyOne rawModel mooseModel allClasses)
		                anyOne.
	remoteServer subclassHierarchy do: [ :sc | 
		(serverDicts at: 1) at: sc put: (self buildNodeFromEntity: sc) ]
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initializeOtherLayers [

	daoTag := (self mooseModel tagNamed: 'daoViolation')
		          color: (Color fromHexString: 'B2182B');
		          yourself.
	implAndIntViolation := (self mooseModel tagNamed: 'implAndIntViolation').
	serviceTag := (self mooseModel tagNamed: 'serviceNoViolation')
		              color: (Color fromHexString: 'EF8A62');
		              yourself.
	self eServices do: [ :c | serviceDict at: c rawModel put: c ].
	self dao do: [ :c | daoDict at: c rawModel put: c ]
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initializePartitioning [

	super initializePartitioning.
	self initializeOtherLayers.

	self addDependenciesToDaoAndTag.
	self addDependenciesToServicesAndTag
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initializeSharedWithDTOs [

	| baseModel dtoAbstractClasses |
	dtoAbstractClasses := { 'EntiteAbstract'. 'EnumerationAbstract' }.

	dtoAbstractClasses do: [ :dto | 
		baseModel := (((FQStringQuery
			                property: #name
			                comparator: #=
			                valueToCompare: dto) runOn:
			               self services anyOne rawModel mooseModel allClasses) 
			              reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.
		sharedDict at: baseModel put: (self buildNodeFromEntity: baseModel).
		baseModel subclassHierarchy do: [ :c | 
			sharedDict at: c put: (self buildNodeFromEntity: c) ] ]
]

{ #category : #building }
MiMultiLayerVisuBuilder >> packageContainsDaoViolation: aPackageNode [

	aPackageNode children do: [ :c | 
		(c rawModel tags anySatisfy: [ :t | t name = 'daoViolation' ]) ifTrue: [ 
			^ true ] ].
	^ false
]

{ #category : #building }
MiMultiLayerVisuBuilder >> packageContainsServiceViolation: aPackageNode [

	aPackageNode children do: [ :c | 
		(c rawModel tags anySatisfy: [ :t | t name = 'serviceNoViolation' ]) 
			ifTrue: [ ^ false ] ].
	^ true
]
