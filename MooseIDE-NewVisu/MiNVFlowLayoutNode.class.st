Class {
	#name : #MiNVFlowLayoutNode,
	#superclass : #MiNVAbstractLayoutNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVFlowLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitFlowLayout: self
]
