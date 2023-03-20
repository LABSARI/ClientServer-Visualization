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
		'sharedLayer'
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
MiLayerVisualizationModel >> addLayer [ 

	continueClient ifTrue: [ 
		continueClient := self addLayerToClientFromLevel: index ].
	continueServer ifTrue: [ 
		continueServer := self addLayerToServerFromLevel: index ].
	index := index + 1.
	self addDependenciesToShared
]

{ #category : #partitioning }
MiLayerVisualizationModel >> addLayerToClientFromLevel: level [

	| newDict currentDict hasAddedSomething |
	self flag: 'to modifty'.
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := self clientLayers at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #server ifTrue: [ 
				(self indexOf: d in: self serverLayers) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d toSharedfrom: self serverLayers) ] ].
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
				(self indexOf: d in: self serverLayers) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d toSharedfrom: self serverLayers) ] ].
			response = #shared ifTrue: [
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		self clientLayers add: newDict.
		^ true ].
	^ false
]

{ #category : #partitioning }
MiLayerVisualizationModel >> addLayerToServerFromLevel: level [

	| newDict currentDict |
	self flag: 'to modifty'.
	newDict := Dictionary new.
	currentDict := self serverLayers at: level.

	currentDict associationsDo: [ :assoc | 
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
				newDict at: d put: newNode ].
			response = #client ifTrue: [ 
				(self indexOf: d in: self clientLayers) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d toSharedfrom: self clientLayers) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	newDict ifNotEmpty: [ 
		self serverLayers add: newDict.
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

{ #category : #accessing }
MiLayerVisualizationModel >> description [

	^ description
]

{ #category : #accessing }
MiLayerVisualizationModel >> description: anObject [

	^ description := anObject
]

{ #category : #actions }
MiLayerVisualizationModel >> followEntity: anEntity [

	self mooseModel: (anEntity isMooseModel
		              ifTrue: [ anEntity ]
		              ifFalse: [ anEntity mooseModel ]).
	
	browser runVisualization.
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
		   c isType and: [ c isAnonymousClass not ] ]) anyOne
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
