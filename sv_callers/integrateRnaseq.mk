# integrate only on rnaseq
# pre-req: tophat

##### MAKE INCLUDES #####
include modules/Makefile.inc

LOGDIR = log/integrate_rnaseq.$(NOW)

..DUMMY := $(shell mkdir -p version; echo "$(INTEGRATE) &> version/integrate.txt")

INTEGRATE = $(HOME)/share/usr/bin/Integrate
INTEGRATE_MINW ?= 2.0
INTEGRATE_LARGENUM ?= 4
INTEGRATE_OPTS = -minW $(INTEGRATE_MINW) -largeNum $(INTEGRATE_LARGENUM)

INTEGRATE_ONCOFUSE = $(RSCRIPT) modules/sv_callers/integrateOncofuse.R
INTEGRATE_ONCOFUSE_OPTS = --oncofuseJar $(ONCOFUSE_JAR) --oncofuseTissueType $(ONCOFUSE_TISSUE_TYPE) --java $(JAVA_BIN) 
ONCOFUSE_TISSUE_TYPE ?= EPI

.SECONDARY:
.DELETE_ON_ERROR:
.PHONY: integrate_rnaseq

integrate_rnaseq : $(foreach sample,$(SAMPLES),integrate_rnaseq/oncofuse/$(sample).oncofuse.txt)

integrate_rnaseq/reads/%.reads.txt integrate_rnaseq/sum/%.sum.tsv integrate_rnaseq/exons/%.exons.tsv integrate_rnaseq/breakpoints/%.breakpoints.tsv : bam/%.bam.md5 bam/%.bam.bai
	$(call LSCRIPT_MEM,8G,40G,"mkdir -p integrate/reads integrate/sum integrate/exons integrate/breakpoints; $(INTEGRATE) fusion $(INTEGRATE_OPTS) -reads integrate/reads/$*.reads.txt -sum integrate/sum/$*.sum.tsv -ex integrate/exons/$*.exons.tsv -bk integrate/breakpoints/$*.breakpoints.tsv $(REF_FASTA) $(INTEGRATE_ANN) $(INTEGRATE_BWTS) $(<M) $(<M)")

integrate_rnaseq/oncofuse/%.oncofuse.txt : integrate_rnaseq/sum/%.sum.tsv integrate_rnaseq/exons/%.exons.tsv integrate_rnaseq/breakpoints/%.breakpoints.tsv
	$(call LSCRIPT_MEM,7G,10G,"$(INTEGRATE_ONCOFUSE) $(INTEGRATE_ONCOFUSE_OPTS) \
		--sumFile $< \
		--exonsFile $(<<) \
		--breakpointsFile $(<<<) \
		--outPrefix $(@D)/$*")


include modules/bam_tools/processBam.mk
