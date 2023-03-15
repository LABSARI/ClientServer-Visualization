"
Base class of the nodes used to describe a layerd visualisation.
One can construct a tree with my subclasses.
I accept visitors.
"
Class {
	#name : #MiNVAbstractNode,
	#superclass : #Object,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVAbstractNode >> acceptVisitor: aVisitor [

	self subclassResponsibility
]
