Class {
	#name : #MiNVAbstractNode,
	#superclass : #Object,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVAbstractNode >> acceptVisitor: aVisitor [

	self subclassResponsibility
]

{ #category : #testing }
MiNVAbstractNode >> hasMultipleNodes [

	^ false
]
