Class {
	#name : #MiLVAbstractNode,
	#superclass : #Object,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVAbstractNode >> acceptVisitor: aVisitor [

	self subclassResponsibility
]

{ #category : #testing }
MiLVAbstractNode >> hasMultipleNodes [

	^ false
]
