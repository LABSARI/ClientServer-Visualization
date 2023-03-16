Class {
	#name : #MiLayerVisualizationModel,
	#superclass : #MiAbstractModel,
	#instVars : [
		'mooseModel',
		'settings',
		'queriesHolder'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #actions }
MiLayerVisualizationModel >> followEntity: anEntity [

	self mooseModel: (anEntity isMooseModel
		              ifTrue: [ anEntity ]
		              ifFalse: [ anEntity mooseModel ]).
	
	browser runVisualization.
]

{ #category : #initialization }
MiLayerVisualizationModel >> initialize [

	super initialize.
	self initializeSettings
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

{ #category : #initialization }
MiLayerVisualizationModel >> settings [
	^settings
]

{ #category : #accessing }
MiLayerVisualizationModel >> settingsChanged: aBoolean [

	aBoolean ifTrue: [ browser runVisualization ]
]

{ #category : #initialization }
MiLayerVisualizationModel >> shouldColor [

	^ settings getItemValue: #shouldColor
]
