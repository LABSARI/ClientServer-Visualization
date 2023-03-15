Class {
	#name : #MiNewVisuModel,
	#superclass : #MiAbstractModel,
	#instVars : [
		'entities',
		'settings',
		'mooseModel'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #accessing }
MiNewVisuModel >> entities [

	^ entities
]

{ #category : #accessing }
MiNewVisuModel >> entities: anObject [

	entities := anObject
]

{ #category : #initialization }
MiNewVisuModel >> initialize [

	super initialize.
	self initializeSettings
]

{ #category : #initialization }
MiNewVisuModel >> initializeSettings [ 

	settings := super initializeSettings.
	settings	addItem: (MiCheckboxSettingItem new
		setValue: true ;
		label: 'Show client package color.' ;
		help: '' ;
		yourself)
		named: #shouldColor
]

{ #category : #accessing }
MiNewVisuModel >> mooseModel [

	^ mooseModel ifNil: [ mooseModel := entities anyOne mooseModel ]
]

{ #category : #accessing }
MiNewVisuModel >> mooseModel: anObject [

	mooseModel := anObject
]

{ #category : #initialization }
MiNewVisuModel >> settings [
	^settings
]

{ #category : #accessing }
MiNewVisuModel >> settingsChanged: aBoolean [

	aBoolean ifTrue: [ browser runVisualization ]
]

{ #category : #initialization }
MiNewVisuModel >> shouldColor [

	^ settings getItemValue: #shouldColor
]
