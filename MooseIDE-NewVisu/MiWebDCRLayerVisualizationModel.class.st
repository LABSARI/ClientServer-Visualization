Class {
	#name : #MiWebDCRLayerVisualizationModel,
	#superclass : #MiLayerVisualizationModel,
	#instVars : [
		'clientClasses'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #initialization }
MiWebDCRLayerVisualizationModel class >> queriesHolder [

	^ MiDQueriesHolder 
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> add: aFamixJavaClass to: aCollection layer: anInteger [

	self
		add: aFamixJavaClass
		toLayer: (aCollection at: anInteger ifAbsentPut: [ Set new ])
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> add: aFamixJavaClass toLayer: aCollection [

	aCollection add: aFamixJavaClass
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addCacheClientDependencies [

	^ (clientLayers at: index) flatCollectAsSet: [ :class | 
		  (self classDependantsFor: class) select: [ :dc | 
			  | exists |
			  exists := outgoingCache includesKey: dc.
			  self addDependency: dc in: incomingCache for: class.
			  self addDependency: class in: outgoingCache for: dc.
			(exists not and: [ incomingCache includesKey: dc ]) ifTrue: [ self tagInViolation: dc ].
			  (self checkIsImplementationOrService: dc) not and: [ exists not ] ] ]
	
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addCacheServerDependencies [

	^ (serverLayers at: index) flatCollectAsSet: [ :class | 
		  (self classDependenciesFor: class) select: [ :dc | 
			  | exits |
			  exits := incomingCache includesKey: dc.
			  self addDependency: dc in: outgoingCache for: class.
			  self addDependency: class in: incomingCache for: dc.
			  (self checkIsImplementationOrService: dc) not and: [ exits not ] ] ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addDependenciesToLastLayers [

	self sharedLayer do: [ :dto | 
		(self classDependantsFor: dto) do: [ :d | 
			((self clientLayers last includes: d) or: [ 
				 self serverLayers last includes: d ]) ifTrue: [ 
				self addDependency: dto in: incomingCache for: d.
				self addDependency: d in: outgoingCache for: dto ] ] ].

	self purgatoryLayer do: [ :p | 
		(self classDependenciesFor: p) do: [ :d | 
			((self clientLayers last includes: d) or: [ 
				 self serverLayers last includes: d ]) ifTrue: [ 
				self addDependency: d in: incomingCache for: p.
				self addDependency: p in: outgoingCache for: d ] ] ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addLayer [

	| allNewSClasses allNewCClasses |
	allNewCClasses := self addCacheClientDependencies.
	allNewSClasses := self addCacheServerDependencies.
	(allNewCClasses union: allNewSClasses) do: [ :class | 
		self partitionClass: class ].
	self setClientClasses.
	self setServerClasses.



	index := index + 1.

	self addDependenciesToLastLayers
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildDescription [


	(description := MiLVVerticalBoxNode new)
		withoutBorder;
		gapSize: 90;
		add: self buildSharedLayer;
		add: self buildMainLayer;
		add: self buildPurgatoryLayer.
	^ description
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildDescriptionForDTOs [

	| dtoDict dtoUsedByClient dtoUsedByServer dtoNotShared dtoBox |
	dtoDict := displayStrategy fetchNotSharedDTOs.
	dtoUsedByClient := self createTypeElementsFor: (dtoDict at: #client).
	dtoUsedByServer := self createTypeElementsFor: (dtoDict at: #server).
	dtoNotShared := self createTypeElementsFor: (dtoDict at: #nothing).

	dtoBox := self createDTOBox.
	dtoUsedByClient ifNotEmpty: [ 
		dtoBox add:
			(self
				 descriptionBoxFor: dtoUsedByClient
				 with: 'Used only by client: ') ].

	dtoUsedByServer ifNotEmpty: [ 
		dtoBox add:
			(self
				 descriptionBoxFor: dtoUsedByServer
				 with: 'Used only by server: ') ].

	dtoNotShared ifNotEmpty: [ 
		dtoBox add:
			(self descriptionBoxFor: dtoNotShared with: 'Not Used:') ].


	^ dtoBox
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainCentralLayer: aLayer with: name [

	^ MiLVVerticalBoxNode new
		  collapse;
		  dashedBorder;
		  name: name;
		  addAll:
			  ((self createTypeElementsFor: aLayer asOrderedCollection) sort: [ 
					   :a 
					   :b | a name < b name ]);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainGroupedLayer: aLayer [

	| entities |
	entities := self entitiesOf: aLayer asOrderedCollection.
	^ MiLVFlowBoxNode new
		  collapse;
		  dashedBorder;
		  name: aLayer size asString;
		  addAll: (entities sort: [ :a :b | a name < b name ]);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainLayer [

	^ MiLVHorizontalBoxNode new
		  withoutBorder;
		  gapSize: 90;
		  add: (MiLVHorizontalBoxNode new
				   dashedBorder;
				   gapSize: 50;
				   name: 'Client';
				   addAll: (self
						    buildMainLayersFor: displayStrategy fetchViolatingClients
						    with: 'Services') reversed;
				   yourself);
		  add: (MiLVHorizontalBoxNode new
				   dashedBorder;
				   gapSize: 50;
				   name: 'Server';
				   addAll: (self
						    buildMainLayersFor: displayStrategy fetchViolatingServers
						    with: 'Implementations');
				   yourself);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainLayersFor: layers with: name [

	^ (layers withIndexCollect: [ :layer :i | 
		  i = 1
			  ifTrue: [ self buildMainCentralLayer: layer with: name ]
			  ifFalse: [ 
				  layer
					  ifNotEmpty: [ self buildMainGroupedLayer: layer ]
					  ifEmpty: [ nil ] ] ]) reject: #isNil
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildPurgatoryLayer [

	^ MiLVFlowBoxNode new
		  collapse;
		  dashedBorder;
		  name: 'Purgatory: ' , purgatoryLayer size asString , ' classes';
		  addAll: (self entitiesOf: purgatoryLayer);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildSharedLayer [

	| dtoBox |
	displayStrategy shouldDisplaySharedDTOs ifFalse: [ 
		^ self buildDescriptionForDTOs ].
	dtoBox := self createDTOBox.

	sharedLayer ifNotEmpty: [ 
		dtoBox addAll: (self createTypeElementsFor: sharedLayer) ].


	^ MiLVHorizontalBoxNode new
		  dashedBorder;
		  name: 'Shared';
		  gapSize: 80;
		  add: dtoBox;
		  yourself
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> checkInViolation: aClass [

	
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> checkIsImplementation: aFamixJavaClass [

	^ (self serverLayers at: 1) includes: aFamixJavaClass
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> checkIsImplementationOrService: aClass [

	^ (self checkIsService: aClass) or: [ 
		  self checkIsImplementation: aClass ]
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> checkIsService: aFamixJavaClass [

	^ (self clientLayers at: 1) includes: aFamixJavaClass
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> clientClasses [ 

	^ clientClasses 
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> commonPackagesFor: elements [

	| groups |
	groups := (elements groupedBy: [ :e | 
		           (e atScope: FamixTPackage) anyOne ])
		          associations.

	^ groups collect: [ :a | 
		  self createPackageElement: a key with: a value ]
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> createDTOBox [

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'DTOs: ' , sharedLayer size asString , ' classes';
		  gapSize: 80;
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> createLinksIn: hNodeDict [

	| cls |
	cls := clientLayers flatten , serverLayers flatten.

	cls do: [ :c | 
		hNodeDict at: c ifPresent: [ :n | 
			"(self classDependantsFor: c) do: [ :d | 
				hNodeDict
					at: d
					ifPresent: [ :hn | 
					(cls includes: d) ifFalse: [ hn dependencyTo: n ] ] ]."
			
			
			(self classDependenciesFor: c) do: [ :d | 
				
				
				hNodeDict
					at: d
					ifPresent: [ :hn | 
					(cls includes: d) ifFalse: [ n dependencyTo: hn ] ] ] ] ] 
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> createPackageElement: famixPackage with: elements [

	^ MiLVPackageElement new
		  model: famixPackage;
		  children: (self createTypeElementsFor: elements);
		  yourself
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> createTypeElementsFor: aCollectionOfMooseEntities [

	^ aCollectionOfMooseEntities collect: [ :me | 
		  MiLVTypeElement new
			  model: me;
			  yourself ]
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> descriptionBoxFor: aCollection with: aName [

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  collapse;
		  name: aName , aCollection size asString;
		  gapSize: 80;
		  addAll: aCollection;
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> displayStrategy [

	^ displayStrategy
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> displayStrategy: anObject [

	displayStrategy := anObject
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> dtos [

	^ queriesHolder DTOClasses result
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> entitiesOf: aLayer [

	^ aLayer size > 100
		  ifTrue: [ self commonPackagesFor: aLayer ]
		  ifFalse: [ self createTypeElementsFor: aLayer ]
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> entitiesWithViolationFrom: aDict [

	^ aDict
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> implementations [

	^ queriesHolder GWTServiceImplementations result
]

{ #category : #initialization }
MiWebDCRLayerVisualizationModel >> initialize [

	super initialize.
	displayStrategy := MiFilterViolationStrategy new
		                   visualizationModel: self;
		                   yourself.

	clientClasses := Dictionary new.
	serverClasses := Dictionary new
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeCaches [

	(serverLayers at: 1) do: [ :c | 
		(self classDependenciesFor: c) do: [ :d | 
			((clientLayers at: 1) like: d) ifNotNil: [ 
				self addDependency: d in: outgoingCache for: c.
				self addDependency: c in: incomingCache for: d ] ] ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeFirstClientLayer [

	"Initialisation of the fist layer of clients"
	self clientLayers add: (Set withAll: self interfaces).
	
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeFirstServerLayer [

	self serverLayers add: (Set withAll: self implementations)
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializePartitioning [

	self initializeFirstClientLayer.
	self initializeFirstServerLayer.
	self initializeSharedWithDTOs.
	self initializeCaches.
	self mooseModel tagNamed: 'violation'.
	continueClient := true.
	continueServer := true.
	index := 1.
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeSharedWithDTOs [

	self sharedLayer addAll: self dtos
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> interfaces [

	^ queriesHolder GWTServices result
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isAlreadyInVisu: aFamixJavaClass [

	^ (self isClient: aFamixJavaClass) or: [ 
		  (self isServer: aFamixJavaClass) or: [ 
			  self isPurgatory: aFamixJavaClass ] ]
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isClient:aClass [
	^ self clientClasses includesKey: aClass
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isDTO: aFamixJavaClass [
	^ sharedLayer includes: aFamixJavaClass 
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isInClientPackage: aClass [

	| testBlock |
	testBlock := [ :p | p name = 'client' ].
	^ (aClass allAtScope: FamixTPackage until: testBlock) anySatisfy:
		  testBlock
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isInServerPackage: aClass [

	| testBlock |
	testBlock := [ :p | p name = 'server' ].
	^ (aClass allAtScope: FamixTPackage until: testBlock) anySatisfy:
		  testBlock
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isPurgatory:aClass [
	^ self purgatoryLayer includes: aClass
]

{ #category : #testing }
MiWebDCRLayerVisualizationModel >> isServer:aClass [
	^ self serverClasses includesKey: aClass
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> moveFromClientLayerToPurgatory: aFamixJavaClass [

	self
		removeClass: aFamixJavaClass
		fromLayer:
		(self clientLayers at: (clientClasses at: aFamixJavaClass)).
	self add: aFamixJavaClass toLayer: purgatoryLayer.
	aFamixJavaClass tagWithName: 'purgatory'
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> moveFromServerLayerToPurgatory: aFamixJavaClass [

	self
		removeClass: aFamixJavaClass
		fromLayer:
		(self serverLayers at: (serverClasses at: aFamixJavaClass)).
	self add: aFamixJavaClass toLayer: purgatoryLayer.
	aFamixJavaClass tagWithName: 'purgatory'
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> partitionClass: aFamixJavaClass [

	(self isDTO: aFamixJavaClass) ifTrue: [ ^ self ].
	(self isPurgatory: aFamixJavaClass) ifTrue: [ ^ self ].
	
	(self isClient: aFamixJavaClass) ifTrue: [
		self moveFromClientLayerToPurgatory: aFamixJavaClass ].
	(self isServer: aFamixJavaClass) ifTrue: [ 
		self moveFromServerLayerToPurgatory: aFamixJavaClass ].
	
	self putClassInCorrespondingLayer: aFamixJavaClass
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> putClassInCorrespondingLayer: aFamixJavaClass [

	incomingCache
		at: aFamixJavaClass
		ifPresent: [ "Introduced by a server class"
			outgoingCache
				at: aFamixJavaClass
				ifPresent: [ "Introduced by a server class and by a client class"
					self add: aFamixJavaClass toLayer: purgatoryLayer.
					aFamixJavaClass tagWithName: 'purgatory' ]
				ifAbsent: [ "Introduced only by a server class" 
					self add: aFamixJavaClass to: serverLayers layer: index + 1 ] ]
		ifAbsent: [ "Not introduced by a server class"
			(outgoingCache includesKey: aFamixJavaClass) ifTrue: [ "Introduced only by a client class" 
				self add: aFamixJavaClass to: clientLayers layer: index + 1 ] ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> removeClass: aFamixJavaClass fromLayer: aLayer [
	aLayer remove: aFamixJavaClass 
	
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> serverClasses [

	^ serverClasses
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> setClientClasses [ 

	self clientLayers allButFirst doWithIndex: [ :l :i | l do: [:c | clientClasses at: c put: i + 1 ]  ] .

]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> setServerClasses [ 
	serverClasses := Dictionary new.
	self serverLayers allButFirst doWithIndex: [ :l :i | l do: [:c | serverClasses at: c put: i + 1]  ] .
]

{ #category : #util }
MiWebDCRLayerVisualizationModel >> tagInViolation: aClass [
	aClass tagWithName: 'violation'
]
