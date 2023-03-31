Class {
	#name : #MiMultiLayerVisuBuilder,
	#superclass : #MiLayerVisualizationBuilder,
	#instVars : [
		'daoDict',
		'serviceDict',
		'daoTag',
		'serviceTag',
		'implAndIntViolation'
	],
	#category : #'MooseIDE-NewVisu-Roassal-builder'
}

{ #category : #adding }
MiMultiLayerVisuBuilder >> addLayerToClientFromLevel: level [

	| newDict currentDict hasAddedSomething |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := mapModel clientLayers at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #server ifTrue: [ 
				(self indexOf: d in: mapModel serverLayers) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d toSharedfrom: mapModel serverLayers) ] ].
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
				(self indexOf: d in: mapModel serverLayers) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d toSharedfrom: mapModel serverLayers) ] ].
			response = #shared ifTrue: [ "(sharedDict at: d) dependencyTo: hNode"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		mapModel clientLayers add: newDict.
		^ true ].
	^ false
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> addLayerToServerFromLevel: level [

	| hasAddedSomething newDict currentDict |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := mapModel serverLayers at: level.
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
				(self indexOf: d in: mapModel clientLayers) > 1 ifTrue: [ 
					level = 1 ifTrue: [ class tagWith: implAndIntViolation ].
					hNode dependencyTo: (self moveClass: d toSharedfrom: mapModel clientLayers) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		mapModel serverLayers add: newDict.
		^ true ].
	^ false
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> buildDescription [

	| serverLayouts clientLayouts |
	serverLayouts := self buildLayoutsFor: mapModel serverLayers reversed: false.
	clientLayouts := self buildLayoutsFor: mapModel clientLayers reversed: true.




	(description := MiLVVerticalLayoutNode new)
		gapSize: 90;
		"add: (MiNVBoxNode new
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
				 yourself);"
		add: (MiLVHorizontalLayoutNode new
				 gapSize: 90;
				 "add: (MiNVBoxNode new
						  name: 'Client';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: clientLayouts;
								   yourself);
						  yourself);"
				 add: (MiLVAbstractBoxNode new
						  name: 'Server';
						  layout: (MiLVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: serverLayouts;
								   yourself);
						  yourself);
				 yourself)";
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
				 yourself)".
	description := MiLVAbstractBoxNode new
		               name: 'UC';
		               layout: description;
		               yourself.
	description := MiLVHorizontalLayoutNode new
		               gapSize: 90;
		               add: description;
		               add: (MiLVAbstractBoxNode new
				                name:
					                'Services: ' , serviceDict values size asString
					                , ' classes';
				                layout: (MiLVFlowLayoutNode new
						                 addAll:
							                 ((self commonPackagesFor: serviceDict values) 
								                  collect: [ :c | 
									                  MiLVAbstractElement new
										                  model: c;
										                  yourself ]);
						                 yourself);
				                yourself);
		               add: (MiLVAbstractBoxNode new
				                name:
					                'DAO: ' , daoDict values size asString
					                , ' classes';
				                layout: (MiLVFlowLayoutNode new
						                 addAll:
							                 ((self commonPackagesFor: daoDict values) 
								                  collect: [ :c | 
									                  MiLVAbstractElement new
										                  model: c;
										                  yourself ]);
						                 yourself);
				                yourself);
		               yourself.
	^ description
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> buildLayoutsFor: dicts reversed: reverse [

	| layouts |
	layouts := dicts withIndexCollect: [ :d :i | 
		           | box layout entities filtered |
		           i = 1
			           ifTrue: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.

				           layout := MiLVVerticalLayoutNode new.
				           box := MiLVAbstractBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself.
				           entities := filtered sort: [ :a :b | a name < b name ] ]
			           ifFalse: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.
				           layout := MiLVFlowLayoutNode new.
				           entities := self commonPackagesFor: filtered.
				           box := MiLVAbstractBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself ].
		           layout addAll: (entities collect: [ :c | 
				            MiLVAbstractElement new
					            model: c;
					            yourself ]).
		           box ].
	^ reverse
		  ifTrue: [ layouts reversed ]
		  ifFalse: [ layouts ]
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> classAlreadyPresent: aClass [

	| response |
	response := super classAlreadyPresent: aClass.
	response = #free ifFalse: [ ^ response ].
	daoDict at: aClass ifPresent: [ ^ #dao ].
	serviceDict at: aClass ifPresent: [ ^ #service ].
	^ #free
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> colorFor: node [

	| entity |
	node color ifNotNil: [ :c | ^ c ].


	entity := node rawModel.
	entity isMooseObject ifFalse: [ ^ Color fromHexString: 'E0E0E0' ].
	(entity isPackage and: [ self packageContainsDaoViolation: node ]) 
		ifTrue: [ ^ self mapModel daoTag color ].
	(entity isPackage and: [ 
		 (serviceDict includesKey: node children anyOne rawModel) and: [ 
			 self packageContainsServiceViolation: node ] ]) ifTrue: [ 
		^ serviceTag color ].

	


	"mapModel shouldColor ifFalse: [ ^ Color fromHexString: '7FC6F6' ].

	^ (self entityIsInClientPackage: entity)
		  ifTrue: [ Color fromHexString: '7FC6F6' ]
		  ifFalse: [ Color fromHexString: 'FFABA3' ]"
	^ Color fromHexString: 'E0E0E0'
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> entitiesWithViolationFrom: aDict [

	| v |
	v := OrderedCollection new.
	daoDict valuesDo: [ :hn | 
		hn dependencies do: [ :d | 
			| c |
			c := d from = hn
				     ifTrue: [ d to ]
				     ifFalse: [ d from ].
			aDict at: c rawModel ifPresent: [ :n | v add: n ] ] ].
	serviceDict valuesDo: [ :hn | 
		hn dependencies do: [ :d | 
			d from = hn ifTrue: [ 
				aDict at: d to rawModel ifPresent: [ :n | v add: n ] ] ] ].
	^ v asSet
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> initialize [

	super initialize.
	daoDict := Dictionary new.
	serviceDict := Dictionary new
]

{ #category : #adding }
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
		mapModel sharedLayer at: baseModel put: (self buildNodeFromEntity: baseModel).
		baseModel subclassHierarchy do: [ :c | 
			mapModel sharedLayer at: c put: (self buildNodeFromEntity: c) ] ]
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> packageContainsDaoViolation: aPackageNode [

	aPackageNode children do: [ :c | 
		(c rawModel tags anySatisfy: [ :t | t name = 'daoViolation' ]) ifTrue: [ 
			^ true ] ].
	^ false
]

{ #category : #adding }
MiMultiLayerVisuBuilder >> packageContainsServiceViolation: aPackageNode [

	aPackageNode children do: [ :c | 
		(c rawModel tags anySatisfy: [ :t | t name = 'serviceNoViolation' ]) 
			ifTrue: [ ^ false ] ].
	^ true
]
