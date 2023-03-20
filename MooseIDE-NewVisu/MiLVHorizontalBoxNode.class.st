Class {
	#name : #MiLVHorizontalBoxNode,
	#superclass : #MiLVAbstractBoxNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVHorizontalBoxNode >> acceptVisitor: aVisitor [

	^ aVisitor visitHorizontalBox: self
]
