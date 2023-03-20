Class {
	#name : #MiLVAbstractBoxNode,
	#superclass : #MiLVAbstractNode,
	#instVars : [
		'name',
		'children',
		'gapSize',
		'style'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #adding }
MiLVAbstractBoxNode >> add: aNode [

	children add: aNode
]

{ #category : #adding }
MiLVAbstractBoxNode >> addAll: aCollectionOfNodes [

	children addAll: aCollectionOfNodes
]

{ #category : #accessing }
MiLVAbstractBoxNode >> backgroundColor [

	^ style background
]

{ #category : #'as yet unclassified' }
MiLVAbstractBoxNode >> backgroundColor: aColor [

	style background: aColor
]

{ #category : #accessing }
MiLVAbstractBoxNode >> borderStyle [

	^style border
]

{ #category : #accessing }
MiLVAbstractBoxNode >> children [

	^ children
]

{ #category : #accessing }
MiLVAbstractBoxNode >> children: anObject [

	children := anObject
]

{ #category : #'as yet unclassified' }
MiLVAbstractBoxNode >> dashedBorder [

	style border: #dashed
]

{ #category : #accessing }
MiLVAbstractBoxNode >> gapSize [

	^ gapSize
]

{ #category : #accessing }
MiLVAbstractBoxNode >> gapSize: anObject [

	gapSize := anObject
]

{ #category : #initialization }
MiLVAbstractBoxNode >> initialize [

	super initialize.
	children := OrderedCollection new.
	gapSize := 3.
	style := MiLVBoxStyle new
]

{ #category : #accessing }
MiLVAbstractBoxNode >> name [

	^ name
]

{ #category : #accessing }
MiLVAbstractBoxNode >> name: anObject [

	name := anObject
]

{ #category : #'as yet unclassified' }
MiLVAbstractBoxNode >> withoutBorder [

	style border: #without
]