Class {
	#name : #MiFilterMultiLayerViolationStrategy,
	#superclass : #MiMultiLayerStrategy,
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> fetchViolatingDaos [

	^ visualizationModel daoLayer select: [ :dao | 
		  dao hasTagNamed: 'daoViolation' ]
]

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> fetchViolatingServices [

	^ visualizationModel serviceLayer reject: [ :service | 
		  service hasTagNamed: 'serviceNoViolation' ]
]
