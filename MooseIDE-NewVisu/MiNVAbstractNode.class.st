Class {
	#name : #MiNVAbstractNode,
	#superclass : #Object,
	#category : #'MooseIDE-NewVisu'
}

{ #category : #visiting }
MiNVAbstractNode >> acceptVisitor: aVisitor [

	self subclassResponsibility
]
