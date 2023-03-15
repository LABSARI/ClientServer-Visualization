Class {
	#name : #MiNVVerticalLayoutNode,
	#superclass : #MiNVLayoutNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVVerticalLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitVerticalLayout: self
]
