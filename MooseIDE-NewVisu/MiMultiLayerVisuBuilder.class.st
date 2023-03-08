Class {
	#name : #MiMultiLayerVisuBuilder,
	#superclass : #MiNewVisuBuilder,
	#instVars : [
		'daoDict',
		'serviceDict',
		'daoTag',
		'serviceTag'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #initialization }
MiMultiLayerVisuBuilder >> addDependenciesToDaoAndTag [


	self
		addDependenciesFrom: (serverDicts at: 1)
		to: daoDict
		execute: [ :impl :dao | 
		(dao hasTag: daoTag) ifFalse: [ dao tagWith: daoTag ] ]
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

	| serverLayouts clientLayouts sharedGroups description |
	serverLayouts := self buildLayoutsFor: serverDicts reversed: false.
	clientLayouts := self buildLayoutsFor: clientDicts reversed: true.
	
	sharedGroups := sharedDict values groupedBy: [ :n | 
		                (n rawModel superclassHierarchy anySatisfy: [ :sc | 
			                 sc name = 'EntitePersistanteAbstract' ])
			                ifTrue: [ #dto ]
			                ifFalse: [ 
				                (n rawModel usesFamixTrait: FamixTEnum)
					                ifTrue: [ #enum ]
					                ifFalse: [ #other ] ] ].
	sharedGroups at: #enum ifAbsentPut: [ OrderedCollection new ].
	sharedGroups at: #other ifAbsentPut: [ OrderedCollection new ].
	sharedGroups at: #dto ifAbsentPut: [ OrderedCollection new ].




	(description := MiNVVerticalLayoutNode new)
		gapSize: 90;
		add: (MiNVBoxNode new
				 name:
					 'Transverse DTOs: ' , (sharedGroups at: #dto) size asString
					 , ' classes';
				 layout: (MiNVFlowLayoutNode new
						  gapSize: 80;
						  addAll:
							  ((self commonPackagesFor: (sharedGroups at: #dto)) collect: [ 
									   :c | 
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
					 'Purgatory: ' , (sharedGroups at: #other) size asString
					 , ' classes';
				 layout: (MiNVFlowLayoutNode new
						  addAll:
							  ((self commonPackagesFor: (sharedGroups at: #other)) 
								   collect: [ :c | 
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
				                name: 'Services';
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
				                name: 'DAO';
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

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initialize [

	super initialize.
	daoDict := Dictionary new.
	serviceDict := Dictionary new
]

{ #category : #initialization }
MiMultiLayerVisuBuilder >> initializeOtherLayers [

	daoTag := (self mooseModel tagNamed: 'daoViolation')
		          color: (Color fromHexString: 'B2182B');
		          yourself.
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
