"
I am a roassal presenter for the MiLayerVisualizationBrowser.
I have a canvas and I use a builder (MiLayerVisualizationBuilder).
"
Class {
	#name : #MiLayerVisualization,
	#superclass : #MiAbstractVisualization,
	#instVars : [
		'builder'
	],
	#category : #'MooseIDE-NewVisu-Presenters'
}

{ #category : #highlighting }
MiLayerVisualization >> highlightShapes [
	

	
]

{ #category : #accessing }
MiLayerVisualization >> model [

	^ self owner model
]

{ #category : #highlighting }
MiLayerVisualization >> run [

	super run.

	builder := MiNewVisuBuilder new
		           mapModel: self model;
		           container: self canvas;
		           yourself.
	builder build
]
