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
MiMultiLayerStrategy >> fetchViolatingEntities [
	
	| incomingCache serverLayer violatingServer |
	incomingCache := visualizationModel incomingCache.
	serverLayer := visualizationModel serverLayers asSet flatten.
	violatingServer := Set new.
	
	visualizationModel purgatoryLayer do: [ :pc |  violatingServer addAll: ((incomingCache at: pc) intersection: serverLayer)].
	violatingServer do: [ :vs | vs tagWithName: 'ServerViolation'  ]
]

{ #category : #filtering }
MiMultiLayerStrategy >> fetchViolatingServices [

	^ self subclassResponsibility
]
