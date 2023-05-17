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
MiFilterMultiLayerViolationStrategy >> fetchViolatingServers [

	^ visualizationModel serverLayers collect: [ :layer | 
		  layer select: [ :server | self serverHasDirectLinkWithDAO: server ] ]
]

{ #category : #filtering }
MiFilterMultiLayerViolationStrategy >> fetchViolatingServices [

	^ visualizationModel serviceLayer reject: [ :service | 
		  service hasTagNamed: 'serviceNoViolation' ]
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
