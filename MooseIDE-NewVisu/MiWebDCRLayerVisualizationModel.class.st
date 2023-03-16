Class {
	#name : #MiWebDCRLayerVisualizationModel,
	#superclass : #MiLayerVisualizationModel,
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> dtos [

	^ queriesHolder DTOClasses result
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> implementations [

	^ queriesHolder GWTServiceImplementations result
]

{ #category : #initialization }
MiWebDCRLayerVisualizationModel >> initialize [
	
	super initialize.
	queriesHolder := MiDQueriesHolder new.
]

{ #category : #queries }
MiWebDCRLayerVisualizationModel >> interfaces [

	^ queriesHolder GWTServices result
]
