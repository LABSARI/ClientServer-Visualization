Class {
	#name : #MiNewVisuModel,
	#superclass : #Object,
	#instVars : [
		'entities'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #accessing }
MiNewVisuModel >> entities [

	^ entities
]

{ #category : #accessing }
MiNewVisuModel >> entities: anObject [

	entities := anObject
]
