Class {
	#name : #MiMultiLayerVisualizationBrowser,
	#superclass : #MiLayerVisualizationBrowser,
	#category : #'MooseIDE-NewVisu-Presenters'
}

{ #category : #'instance creation' }
MiMultiLayerVisualizationBrowser class >> newModel [

	^ MiMultiLlayerVisualizationModel new
]

{ #category : #'as yet unclassified' }
MiMultiLayerVisualizationBrowser class >> visualizationBuilder [

	^ MiMultiLayerVisuBuilder new
]

{ #category : #visiting }
MiMultiLayerVisualizationBrowser >> changeColorFor: class [

	((self mapModel isServer: class) and: [ self mapModel isInClientPackage: class ]) 
		ifTrue: [ ^ Color fromHexString: 'F4A582' ].

	((self mapModel isClient: class) and: [ self mapModel isInServerPackage: class ]) 
		ifTrue: [ ^ Color fromHexString: 'F4A582' ].

	^ nil
]
