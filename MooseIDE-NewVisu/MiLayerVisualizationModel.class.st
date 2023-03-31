Class {
	#name : #MiLayerVisualizationModel,
	#superclass : #MiAbstractModel,
	#instVars : [
		'mooseModel',
		'settings',
		'queriesHolder',
		'description',
		'index',
		'continueClient',
		'continueServer',
		'clientLayers',
		'purgatoryLayer',
		'serverLayers',
		'sharedLayer',
		'incomingCache',
		'outgoingCache'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #partitioning }
MiLayerVisualizationModel >> addDependenciesToShared [

	"Add dependencies to shared from last added layers."

	self sharedLayer associationsDo: [ :a | 
		(self classDependantsFor: a key) do: [ :c | 
			(self serverLayers at: index)
				at: c
				ifPresent: [ :n | n dependencyTo: a value ] ].
		(self classDependenciesFor: a key) do: [ :c | 
			(self clientLayers at: index)
				at: c
				ifPresent: [ :n | a value dependencyTo: n ] ] ]
]

{ #category : #partitioning }
MiLayerVisualizationModel >> addDependency: valueEntity in: aDictionary for: keyEntity [

	aDictionary
		at: keyEntity
		ifPresent: [ :collection | collection add: valueEntity ]
		ifAbsentPut: [ OrderedCollection with: valueEntity ]
]

{ #category : #partitioning }
MiLayerVisualizationModel >> addLayerToClientFromLevel: level [

	| newLayer currentLayer hasAddedSomething |
	hasAddedSomething := false.
	newLayer := Set new.
	currentLayer := self clientLayers at: level.


	currentLayer do: [ :class | "outgoings"
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #server ifTrue: [ 
				(self indexOf: d in: self serverLayers) > 1 ifTrue: [ 
					self moveClass: d toSharedfrom: self serverLayers ] ] ].
		"incomings"
		(self classDependantsFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #free ifTrue: [ newLayer add: d ].
			response = #server ifTrue: [ 
				(self indexOf: d in: self serverLayers) > 1 ifTrue: [ 
					self moveClass: d toSharedfrom: self serverLayers ] ] ] ].
	newLayer ifNotEmpty: [ 
		self clientLayers add: newLayer.
		^ true ].
	^ false
]

{ #category : #partitioning }
MiLayerVisualizationModel >> addLayerToServerFromLevel: level [

	| newLayer currentLayer |
	newLayer := Set new.
	currentLayer := self serverLayers at: level.

	currentLayer associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependantsFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #client ifTrue: [  ] ].

		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #free ifTrue: [ 
				| newNode |
				newNode := self buildNodeFromEntity: d.
				hNode dependencyTo: newNode.
				newLayer at: d put: newNode ].
			response = #client ifTrue: [ 
				(self indexOf: d in: self clientLayers) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d toSharedfrom: self clientLayers) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	newLayer ifNotEmpty: [ 
		self serverLayers add: newLayer.
		^ true ].
	^ false
]

{ #category : #partitioning }
MiLayerVisualizationModel >> classAlreadyPresent: aClass [

	self clientLayers do: [ :d | d at: aClass ifPresent: [ ^ #client ] ].
	self serverLayers do: [ :d | d at: aClass ifPresent: [ ^ #server ] ].
	self sharedLayer at: aClass ifPresent: [ ^ #shared ].
	self purgatoryLayer at: aClass ifPresent: [ ^ #purgatory ].
	^ #free
]

{ #category : #partitioning }
MiLayerVisualizationModel >> classDependantsFor: aClass [

	^ ((aClass queryAllIncoming withoutSelfLoops reject: [ :a | 
		    (a target isCollection
			     ifTrue: [ a target first ]
			     ifFalse: [ a target ]) isStub ]) collect: [ :e | 
		   self rootClass: e source ]) asSet
]

{ #category : #partitioning }
MiLayerVisualizationModel >> classDependenciesFor: aClass [

	^ (aClass allProviders
		  reject: [ :c | c isStub ]
		  thenCollect: [ :e | self rootClass: e ]) asSet
]

{ #category : #accessing }
MiLayerVisualizationModel >> clientLayers [

	^ clientLayers
]

{ #category : #accessing }
MiLayerVisualizationModel >> clientLayers: anObject [

	clientLayers := anObject
]

{ #category : #building }
MiLayerVisualizationModel >> commonPackagesFor: elements [

	| groups |
	groups := (elements groupedBy: [ :e | 
		           (e atScope: FamixTPackage) anyOne ])
		          associations.

	^ groups collect: [ :a | 
		  self createPackageElement: a key with: a value ]
]

{ #category : #building }
MiLayerVisualizationModel >> createPackageElement: famixPackage with: elements [

	^ MiLVPackageElement new
		  model: famixPackage;
		  children: (self createTypeElementsFor: elements);
		  yourself
]

{ #category : #building }
MiLayerVisualizationModel >> createTypeElementsFor: aCollectionOfMooseEntities [

	^ aCollectionOfMooseEntities collect: [ :me | 
		  MiLVTypeElement new
			  model: me;
			  yourself ]
]

{ #category : #accessing }
MiLayerVisualizationModel >> description [

	^ description
]

{ #category : #accessing }
MiLayerVisualizationModel >> description: anObject [

	^ description := anObject
]

{ #category : #building }
MiLayerVisualizationModel >> entitiesOf: aLayer [

	^ aLayer size > 100
		  ifTrue: [ self commonPackagesFor: aLayer ]
		  ifFalse: [ self createTypeElementsFor: aLayer ]
]

{ #category : #actions }
MiLayerVisualizationModel >> followEntity: anEntity [

	self mooseModel: (anEntity isMooseModel
		              ifTrue: [ anEntity ]
		              ifFalse: [ anEntity mooseModel ]).
	
	browser runVisualization.
]

{ #category : #accessing }
MiLayerVisualizationModel >> incomingCache [

	^ incomingCache
]

{ #category : #partitioning }
MiLayerVisualizationModel >> indexOf: aClass in: dicts [

	dicts withIndexDo: [ :d :i | d at: aClass ifPresent: [ ^ i ] ].
	^ -1
]

{ #category : #initialization }
MiLayerVisualizationModel >> initialize [

	super initialize.
	self initializeSettings.
	incomingCache := Dictionary new.
	outgoingCache := Dictionary new.
	sharedLayer := Set new.
	purgatoryLayer := Set new.
	serverLayers := OrderedCollection new.
	clientLayers := OrderedCollection new
]

{ #category : #initialization }
MiLayerVisualizationModel >> initializeSettings [ 

	settings := super initializeSettings.
	settings	addItem: (MiCheckboxSettingItem new
		setValue: true ;
		label: 'Show client package color.' ;
		help: '' ;
		yourself)
		named: #shouldColor
]

{ #category : #accessing }
MiLayerVisualizationModel >> mooseModel [

	^ mooseModel
]

{ #category : #accessing }
MiLayerVisualizationModel >> mooseModel: aMooseModel [

	mooseModel := aMooseModel.
	queriesHolder mooseModel: mooseModel
]

{ #category : #partitioning }
MiLayerVisualizationModel >> moveClass: aClass toSharedfrom: collectionOfDicts [

	| hNode |
	self flag: 'to modify'.
	collectionOfDicts do: [ :d | 
		(d removeKey: aClass ifAbsent: [ nil ]) ifNotNil: [ :n | 
			hNode := n.
			self purgatoryLayer at: aClass put: hNode.
			^ hNode ] ].

	^ nil
]

{ #category : #accessing }
MiLayerVisualizationModel >> outgoingCache [

	^ outgoingCache
]

{ #category : #accessing }
MiLayerVisualizationModel >> purgatoryLayer [

	^ purgatoryLayer
]

{ #category : #accessing }
MiLayerVisualizationModel >> purgatoryLayer: anObject [

	purgatoryLayer := anObject
]

{ #category : #building }
MiLayerVisualizationModel >> rootClass: anEntity [

	^ (anEntity atScopeWithProperty: [ :c | 
		   c isType and: [ c typeContainer isPackage ] ]) anyOne
]

{ #category : #accessing }
MiLayerVisualizationModel >> serverLayers [

	^ serverLayers
]

{ #category : #accessing }
MiLayerVisualizationModel >> serverLayers: anObject [

	serverLayers := anObject
]

{ #category : #initialization }
MiLayerVisualizationModel >> settings [
	^settings
]

{ #category : #accessing }
MiLayerVisualizationModel >> settingsChanged: aBoolean [

	aBoolean ifTrue: [ browser runVisualization ]
]

{ #category : #accessing }
MiLayerVisualizationModel >> sharedLayer [

	^ sharedLayer
]

{ #category : #accessing }
MiLayerVisualizationModel >> sharedLayer: anObject [

	sharedLayer := anObject
]

{ #category : #initialization }
MiLayerVisualizationModel >> shouldColor [

	^ settings getItemValue: #shouldColor
]
