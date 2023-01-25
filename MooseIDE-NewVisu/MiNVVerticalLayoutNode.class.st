Class {
	#name : #MiNVVerticalLayoutNode,
	#superclass : #MiNVLayoutNode,
	#category : #'MooseIDE-NewVisu'
}

{ #category : #visiting }
MiNVVerticalLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitVerticalLayout: self
]
