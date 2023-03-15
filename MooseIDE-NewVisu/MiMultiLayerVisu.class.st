Class {
	#name : #MiMultiLayerVisu,
	#superclass : #MiNewVisu,
	#category : #'MooseIDE-NewVisu-Browser'
}

{ #category : #running }
MiMultiLayerVisu >> run [

	builder := MiMultiLayerVisuBuilder new
		           mapModel: self model;
		           container: self canvas;
		           yourself.
	builder build
]
