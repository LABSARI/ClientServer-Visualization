Class {
	#name : #MiLayerVisualizationBrowser,
	#superclass : #MiAbstractBrowser,
	#instVars : [
		'visualization'
	],
	#category : #'MooseIDE-NewVisu-Presenters'
}

{ #category : #'world menu' }
MiLayerVisualizationBrowser class >> menuItem [

	^ #MiLayerVisualizationBrowser
]

{ #category : #'instance creation' }
MiLayerVisualizationBrowser class >> newModel [

	^ MiWebDCRLayerVisualizationModel new
]

{ #category : #'world menu' }
MiLayerVisualizationBrowser class >> title [

	^ 'New Visualization'
]

{ #category : #testing }
MiLayerVisualizationBrowser >> canFollowEntity: anObject [

	^ anObject isMooseObject
]

{ #category : #actions }
MiLayerVisualizationBrowser >> followEntity: anEntity [

	model followEntity: anEntity
]

{ #category : #testing }
MiLayerVisualizationBrowser >> hasSettings [

	^ true
]

{ #category : #initialization }
MiLayerVisualizationBrowser >> initializeLayout [

	self layout: (SpBoxLayout newTopToBottom
			 add: visualization;
			 yourself)
]

{ #category : #initialization }
MiLayerVisualizationBrowser >> initializePresenters [

	visualization := self instantiate: MiLayerVisualization on: model.
	self initializeLayout
]

{ #category : #accessing }
MiLayerVisualizationBrowser >> initializeWindow: aMiWindowPresenter [

	super initializeWindow: aMiWindowPresenter.
	aMiWindowPresenter initialExtent: self currentWorld extent
]

{ #category : #accessing }
MiLayerVisualizationBrowser >> miSelectedItem [

	^ nil
]

{ #category : #actions }
MiLayerVisualizationBrowser >> runVisualization [

	visualization run
]

{ #category : #testing }
MiLayerVisualizationBrowser >> settings [

	model settings open
]
