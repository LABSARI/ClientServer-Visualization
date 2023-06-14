Class {
	#name : #HBoxNodeStyle,
	#superclass : #HBorderAndTitleStyle,
	#category : #'MooseIDE-NewVisu-Roassal-builder'
}

{ #category : #building }
HBoxNodeStyle >> layoutOn: aGroupOfShapes parent: anHNode [
	aGroupOfShapes ifEmpty: [ ^ self ].
	
	self relayout: aGroupOfShapes parent: anHNode.
	
	
]
