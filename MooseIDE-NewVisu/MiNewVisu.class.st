Class {
	#name : #MiNewVisu,
	#superclass : #MiAbstractVisualization,
	#instVars : [
		'builder'
	],
	#category : #'MooseIDE-NewVisu'
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

	builder := MiNewVisuBuilder new
		           mapModel: self model;
		           container: self canvas;
		           yourself.
	builder build
]
