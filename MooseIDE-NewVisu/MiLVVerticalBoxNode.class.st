Class {
	#name : #MiLVVerticalBoxNode,
	#superclass : #MiLVAbstractBoxNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVVerticalBoxNode >> acceptVisitor: aVisitor [

	^ aVisitor visitVerticalBox: self
]
