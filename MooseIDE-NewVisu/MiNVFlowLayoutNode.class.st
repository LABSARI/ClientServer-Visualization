Class {
	#name : #MiNVFlowLayoutNode,
	#superclass : #MiNVLayoutNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVFlowLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitFlowLayout: self
]
