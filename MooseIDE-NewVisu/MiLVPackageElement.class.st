Class {
	#name : #MiLVPackageElement,
	#superclass : #MiLVAbstractElement,
	#instVars : [
		'children'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVPackageElement >> acceptVisitor: aVisitor [

	^ aVisitor visitPackageElement: self
]

{ #category : #accessing }
MiLVPackageElement >> children [

	^ children
]

{ #category : #accessing }
MiLVPackageElement >> children: anObject [

	children := anObject
]
