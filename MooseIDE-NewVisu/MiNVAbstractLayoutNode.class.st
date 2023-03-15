Class {
	#name : #MiNVAbstractLayoutNode,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'children',
		'query',
		'gapSize'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #initialization }
MiNVAbstractLayoutNode >> add: aNVNode [

	children add: aNVNode
]

{ #category : #initialization }
MiNVAbstractLayoutNode >> addAll: aCollection [

	children addAll: aCollection
]

{ #category : #initialization }
MiNVAbstractLayoutNode >> children [

	^ children
]

{ #category : #accessing }
MiNVAbstractLayoutNode >> gapSize [

	^ gapSize
]

{ #category : #accessing }
MiNVAbstractLayoutNode >> gapSize: anObject [

	gapSize := anObject
]

{ #category : #initialization }
MiNVAbstractLayoutNode >> initialize [

	super initialize.
	children := OrderedCollection new.
	gapSize := 3
]

{ #category : #accessing }
MiNVAbstractLayoutNode >> query [

	^ query
]

{ #category : #accessing }
MiNVAbstractLayoutNode >> query: anObject [

	query := anObject
]
