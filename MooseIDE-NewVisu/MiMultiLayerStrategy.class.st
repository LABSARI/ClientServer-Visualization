Class {
	#name : #MiMultiLayerStrategy,
	#superclass : #MiAbstractDisplayStrategy,
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiMultiLayerStrategy >> fetchViolatingDaos [

	^ self subclassResponsibility 
]

{ #category : #filtering }
MiMultiLayerStrategy >> fetchViolatingServers [
	
	^ self subclassResponsibility
]

{ #category : #filtering }
MiMultiLayerStrategy >> fetchViolatingServices [

	^ self subclassResponsibility
]

{ #category : #filtering }
MiMultiLayerStrategy >> fetchViolatingTransverse [

	^ self subclassResponsibility
]
