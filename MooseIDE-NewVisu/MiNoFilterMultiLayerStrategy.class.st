Class {
	#name : #MiNoFilterMultiLayerStrategy,
	#superclass : #MiMultiLayerStrategy,
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiNoFilterMultiLayerStrategy >> fetchViolatingDaos [

	^ visualizationModel daoLayer
]

{ #category : #filtering }
MiNoFilterMultiLayerStrategy >> fetchViolatingServers [
	
	^ visualizationModel serverLayers
]

{ #category : #filtering }
MiNoFilterMultiLayerStrategy >> fetchViolatingServices [

	^ visualizationModel serviceLayer
]

{ #category : #filtering }
MiNoFilterMultiLayerStrategy >> fetchViolatingTransverse [

	^ visualizationModel transverseLayer
]
