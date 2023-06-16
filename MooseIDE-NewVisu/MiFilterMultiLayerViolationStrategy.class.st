Class {
	#name : #MiFilterMultiLayerViolationStrategy,
	#superclass : #MiMultiLayerStrategy,
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> fetchViolatingDaos [

	^ visualizationModel daoLayer select: [ :dao | 
		  ((visualizationModel classDependenciesFor: dao) anySatisfy: [ :c | 
			   (visualizationModel serviceLayer includes: c) or: [ 
				   visualizationModel serverLayers flatten includes: c ] ]) or: [ 
			  (visualizationModel classDependantsFor: dao) anySatisfy: [ :c | 
				  visualizationModel serverLayers flatten includes: c ] ] ]
]

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> fetchViolatingServers [

	^ visualizationModel serverLayers collect: [ :layer | 
		  layer select: [ :server | self serverHasDirectLinkWithDAO: server ] ]
]

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> fetchViolatingServices [

	^ visualizationModel serviceLayer select: [ :service | 
		  ((visualizationModel classDependantsFor: service) anySatisfy: [ :c | 
			   visualizationModel daoLayer includes: c ]) or: [ 
			  (visualizationModel classDependenciesFor: service) anySatisfy: [ 
				  :c | visualizationModel serverLayers flatten includes: c ] ] ]
]

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> serverHasDirectLinkWithDAO: aServerClass [

	| testBlock |
	testBlock := [ :c | 
	             | actualClass |
	             actualClass := visualizationModel rootClass: c.
	             (visualizationModel daoLayer includes: c) ifTrue: [ 
		             ^ true ] ].
	aServerClass allClients do: testBlock.
	aServerClass allProviders do: testBlock.


	^ false
]
