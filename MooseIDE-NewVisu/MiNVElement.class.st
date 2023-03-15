"
I am a node describing a final element, a leaf.
"
Class {
	#name : #MiNVElement,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'model'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVElement >> acceptVisitor: aVisitor [

	^ aVisitor visitElement: self
]

{ #category : #accessing }
MiNVElement >> model [

	^ model
]

{ #category : #accessing }
MiNVElement >> model: anObject [

	model := anObject
]
