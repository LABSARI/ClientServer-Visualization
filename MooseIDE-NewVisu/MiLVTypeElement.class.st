Class {
	#name : #MiLVTypeElement,
	#superclass : #MiLVAbstractElement,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVTypeElement >> acceptVisitor: aVisitor [

	^ aVisitor visitTypeElement: self
]
