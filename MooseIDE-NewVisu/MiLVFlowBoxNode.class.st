Class {
	#name : #MiLVFlowBoxNode,
	#superclass : #MiLVAbstractBoxNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVFlowBoxNode >> acceptVisitor: aVisitor [

	^ aVisitor visitFlowBox: self
]
