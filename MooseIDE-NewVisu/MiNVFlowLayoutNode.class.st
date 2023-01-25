Class {
	#name : #MiNVFlowLayoutNode,
	#superclass : #MiNVLayoutNode,
	#category : #'MooseIDE-NewVisu'
}

{ #category : #visiting }
MiNVFlowLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitFlowLayout: self
]
