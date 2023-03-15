Class {
	#name : #MiNVVerticalLayoutNode,
	#superclass : #MiNVAbstractLayoutNode,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVVerticalLayoutNode >> acceptVisitor: aVisitor [

	^ aVisitor visitVerticalLayout: self
]
