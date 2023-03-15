Class {
	#name : #MiNewVisuBrowser,
	#superclass : #MiAbstractBrowser,
	#instVars : [
		'visualization'
	],
	#category : #'MooseIDE-NewVisu-Browser'
}

{ #category : #'world menu' }
MiNewVisuBrowser class >> menuItem [

	^ #MiNewVisuBrowser
]

{ #category : #'instance creation' }
MiNewVisuBrowser class >> newModel [

	^ MiNewVisuModel new
]

{ #category : #'world menu' }
MiNewVisuBrowser class >> title [

	^ 'New Visualization'
]

{ #category : #'as yet unclassified' }
MiNewVisuBrowser class >> visuClass [

	^ MiNewVisu
]

{ #category : #testing }
MiNewVisuBrowser >> canFollowEntity: anObject [

	^ anObject isMooseObject
]

{ #category : #actions }
MiNewVisuBrowser >> followEntity: anEntity [

	model entities: (anEntity asMooseGroup select: [ :e | 
			 e isInterface and: [ 
				 (e superclassHierarchy anySatisfy: [ :c | c name = 'Remote' ]) 
					 and: [ e isStub not ] ] ]).
	self runVisualization
]

{ #category : #testing }
MiNewVisuBrowser >> hasSettings [

	^ true
]

{ #category : #initialization }
MiNewVisuBrowser >> initializeLayout [

	self layout: (SpBoxLayout newTopToBottom
			 add: visualization;
			 yourself)
]

{ #category : #initialization }
MiNewVisuBrowser >> initializePresenters [

	visualization := self instantiate: self class visuClass on: model.
	self initializeLayout
]

{ #category : #accessing }
MiNewVisuBrowser >> initializeWindow: aMiWindowPresenter [

	super initializeWindow: aMiWindowPresenter.
	aMiWindowPresenter initialExtent: self currentWorld extent
]

{ #category : #accessing }
MiNewVisuBrowser >> miSelectedItem [

	^ nil
]

{ #category : #actions }
MiNewVisuBrowser >> runVisualization [

	visualization run
]

{ #category : #initialization }
MiNewVisuBrowser >> setModelBeforeInitialization: aBrowserModel [
	aBrowserModel ifNil: [ ^self ].

	model := aBrowserModel.
	model browser: self
]

{ #category : #testing }
MiNewVisuBrowser >> settings [

	model settings open
]
