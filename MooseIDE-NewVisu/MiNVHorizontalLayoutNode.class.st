Class {
	#name : #MiNVHorizontalLayoutNode,
	#superclass : #MiNVAbstractLayoutNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVHorizontalLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitHorizontalLayout: self
]
