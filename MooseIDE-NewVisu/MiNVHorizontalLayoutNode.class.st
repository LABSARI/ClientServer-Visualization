Class {
	#name : #MiNVHorizontalLayoutNode,
	#superclass : #MiNVLayoutNode,
	#category : #'MooseIDE-NewVisu'
}

{ #category : #visiting }
MiNVHorizontalLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitHorizontalLayout: self
]
