Class {
	#name : #MiNVHorizontalLayoutNode,
	#superclass : #MiNVLayoutNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVHorizontalLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitHorizontalLayout: self
]
