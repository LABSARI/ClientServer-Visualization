Class {
	#name : #MiWebDCRLayerVisualizationModel,
	#superclass : #MiLayerVisualizationModel,
	#instVars : [
		'displayStrategy'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

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
			  | exits |
			  exits := outgoingCache includesKey: dc.
			  self addDependency: dc in: incomingCache for: class.
			  self addDependency: class in: outgoingCache for: dc.
			  exits not ] ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addCacheServerDependencies [

	^ (serverLayers at: index) flatCollectAsSet: [ :class | 
		  (self classDependenciesFor: class) select: [ :dc | 
			  | exits |
			  exits := incomingCache includesKey: dc.
			  self addDependency: dc in: outgoingCache for: class.
			  self addDependency: class in: incomingCache for: dc.
			  exits ] ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addDependency: valueEntity in: aDictionary for: keyEntity [

	aDictionary
		at: keyEntity
		ifPresent: [ :collection | collection add: valueEntity ]
		ifAbsentPut: [ OrderedCollection with: valueEntity ]
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> addLayer [

	| allNewClasses |
	
	allNewClasses := self addCacheClientDependencies.
	allNewClasses := allNewClasses union: self addCacheServerDependencies.
	
	allNewClasses do: [ :class | self partitionClass: class ].
	index := index + 1
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
MiWebDCRLayerVisualizationModel >> buildMainCentralLayer: aLayer [

	^ MiLVVerticalBoxNode new
		  name: aLayer size asString , '/' , aLayer size asString;
		  addAll:
			  ((self createTypeElementsFor: aLayer asOrderedCollection) sort: [ 
					   :a 
					   :b | a name < b name ]);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainGroupedLayer: aLayer [

	| filtered entities |
	filtered := self entitiesWithViolationFrom:
		            aLayer asOrderedCollection.
	entities := self commonPackagesFor: filtered.
	^ MiLVFlowBoxNode new
		  name: filtered size asString , '/' , aLayer size asString;
		  addAll: (entities sort: [ :a :b | a name < b name ]);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainLayer [

	| impls interfaces |
	impls := self createTypeElementsFor: self implementations.
	interfaces := self createTypeElementsFor: self interfaces.

	^ MiLVHorizontalBoxNode new
		  withoutBorder;
		  gapSize: 90;
		  add: (MiLVHorizontalBoxNode new
				   dashedBorder;
				   name: 'Client';
				   addAll: (self buildMainLayersFor: (displayStrategy fetchViolatingClients)) reversed;
				   yourself);
		  add: (MiLVHorizontalBoxNode new
				   dashedBorder;
				   name: 'Server';
				   addAll: (self buildMainLayersFor: displayStrategy fetchViolatingServers);
				   yourself);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildMainLayersFor: layers [

	^ layers withIndexCollect: [ :layer :i | 
		  i = 1
			  ifTrue: [ self buildMainCentralLayer:  layer ]
			  ifFalse: [ self buildMainGroupedLayer: layer ] ]
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildPurgatoryLayer [

	^ MiLVFlowBoxNode new
		  dashedBorder;
		  name: 'Purgatory: ' , purgatoryLayer size asString , ' classes';
		  addAll: (self commonPackagesFor: purgatoryLayer);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> buildSharedLayer [

	| sharedGroups dtoDict dtoUsedByClient dtoUsedByServer dtoNotShared dtoSize dtoBox |
	sharedGroups := Dictionary new.
	sharedGroups at: #dto put: sharedLayer.
	sharedGroups at: #enum put: #(  ).

	dtoDict := displayStrategy fetchNotSharedDTOs.
	dtoUsedByClient := self createTypeElementsFor: (dtoDict at: #client).
	dtoUsedByServer := self createTypeElementsFor: (dtoDict at: #server).
	dtoNotShared := self createTypeElementsFor: (dtoDict at: #nothing).

	dtoSize := dtoUsedByClient size + dtoUsedByServer size
	           + dtoNotShared size.

	dtoBox := MiLVFlowBoxNode new
		          dashedBorder;
		          name:
			          'DTOs: ' , dtoSize asString , '/'
			          , sharedLayer size asString , ' classes';
		          gapSize: 80;
		          yourself.
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
			(self descriptionBoxFor: dtoNotShared with: 'Not shared :') ].

	^ MiLVHorizontalBoxNode new
		  dashedBorder;
		  name: 'Shared';
		  gapSize: 80;
		  add: dtoBox;
		  add: (MiLVFlowBoxNode new
				   dashedBorder;
				   name:
					   'Enums: ' , (sharedGroups at: #enum) size asString
					   , ' classes';
				   gapSize: 80;
				   addAll:
					   ((self commonPackagesFor: (sharedGroups at: #enum)) collect: [ 
							    :c | 
							    MiLVAbstractElement new
								    model: c;
								    yourself ]);
				   yourself);
		  yourself
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> commonPackagesFor: elements [

	| groups |
	groups := (elements groupedBy: [ :e | 
		           (e atScope: FamixTPackage) anyOne ])
		          associations.

	^ groups collect: [ :a | 
		  self createPackageElement: a key with: a value ]
]

{ #category : #building }
MiWebDCRLayerVisualizationModel >> createPackageElement: famixPackage with: elements [

	^ MiLVPackageElement new
		  model: famixPackage;
		  children: (self createTypeElementsFor: elements);
		  yourself
]

{ #category : #building }
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
		  name: aName , aCollection size asString;
		  gapSize: 80;
		  addAll: aCollection;
		  yourself
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> displayStrategy [

	^ displayStrategy
]

{ #category : #accessing }
MiWebDCRLayerVisualizationModel >> displayStrategy: anObject [

	displayStrategy := anObject
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> dtos [

	^ queriesHolder DTOClasses result
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
	queriesHolder := MiDQueriesHolder new.
	displayStrategy := MiFilterViolationStrategy new
		                   visualizationModel: self;
		                   yourself
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

	continueClient := true.
	continueServer := true.
	index := 1
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> initializeSharedWithDTOs [

	self sharedLayer addAll: self dtos
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> interfaces [

	^ queriesHolder GWTServices result
]

{ #category : #partitioning }
MiWebDCRLayerVisualizationModel >> partitionClass: aFamixJavaClass [

	incomingCache
		at: aFamixJavaClass
		ifPresent: [ "Intruduit par une classe du serveur"
			outgoingCache
				at: aFamixJavaClass
				ifPresent: [ "Introduit par une classe du serveur et par une classe du client" 
					self add: aFamixJavaClass toLayer: purgatoryLayer ]
				ifAbsent: [ "Intruduit uniquement par une classe du serveur" 
					self add: aFamixJavaClass to: serverLayers layer: index + 1 ] ]
		ifAbsent: [ "Pas intruduit par une classe du serveur"
			(outgoingCache includesKey: aFamixJavaClass) ifTrue: [ "Introduit uniquement par une classe du client" 
				self add: aFamixJavaClass to: clientLayers layer: index + 1 ] ]
]
