Class {
	#name : #MiNewVisu,
	#superclass : #MiAbstractVisualization,
	#instVars : [
		'builder'
	],
	#category : #'MooseIDE-NewVisu-Presenters'
}

{ #category : #highlighting }
MiNewVisu >> highlightShapes [
	

	
]

{ #category : #accessing }
MiNewVisu >> model [

	^ self owner model
]

{ #category : #highlighting }
MiNewVisu >> run [

	super run.

	builder := MiNewVisuBuilder new
		           mapModel: self model;
		           container: self canvas;
		           yourself.
	builder build
]
