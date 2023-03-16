Class {
	#name : #BaselineOfLayerVisualization,
	#superclass : #BaselineOf,
	#category : #BaselineOfLayerVisualization
}

{ #category : #baselines }
BaselineOfLayerVisualization >> baseline: spec [

	<baseline>
	spec for: #common do: [ spec package: 'MooseIDE-NewVisu' ]
]
