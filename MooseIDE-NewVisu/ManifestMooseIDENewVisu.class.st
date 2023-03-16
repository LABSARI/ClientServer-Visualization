"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestMooseIDENewVisu,
	#superclass : #PackageManifest,
	#category : #'MooseIDE-NewVisu-Manifest'
}

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleCodeCruftLeftInMethodsRuleV1FalsePositive [
	^ #(#(#(#RGClassDefinition #(#MiNewVisuBuilder)) #'2023-02-08T12:55:09.209896+01:00') )
]

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleCollectionProtocolRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#MiNewVisuBuilder #clients #false)) #'2022-11-24T12:37:23.330758+01:00') )
]

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleInconsistentMethodClassificationRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#MiLayerVisualization #run #false)) #'2023-01-25T09:58:07.842579+01:00') )
]

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleLongMethodsRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#MiNewVisuBuilder #buildShapes #false)) #'2023-01-16T14:28:25.213065+01:00') #(#(#RGMethodDefinition #(#MiNewVisuBuilder #build #false)) #'2023-02-01T14:17:32.006048+01:00') #(#(#RGClassDefinition #(#MiNewVisuBuilder)) #'2023-02-08T13:01:49.559245+01:00') )
]

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleSearchingLiteralRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#MiNewVisuBuilder #build #false)) #'2023-03-02T10:48:14.310135+01:00') #(#(#RGMethodDefinition #(#MiNewVisuBuilder #buildDescription #false)) #'2023-03-03T15:26:16.065919+01:00') )
]
