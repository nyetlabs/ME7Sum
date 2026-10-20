# Rules only. No variables set
# included by GNUMakefile

$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(ECHO) Compiling $(notdir $<) ...
	$(DEBUG)$(CC) $(CFLAGS) -o $@ -c $<

$(EXE): $(OBJ)
	@mkdir -p $(dir $@)
	$(ECHO) Linking $@ ...
	$(DEBUG)$(LD) $(OBJ) $(LDFLAGS) $(addprefix -l,$(LIBS)) -o $@
	$(ECHO) Done

.PHONY: zip tar stage package
stage: all
	$(RM) -r $(STAGE_DIR)
	mkdir -p $(STAGE_DIR)
	$(CP) $(EXE) $(PACKAGE_FILES) $(STAGE_DIR)

zip tar package: $(BUILD_DIR)/$(PACKAGE)
%.tar.gz: stage
	$(RM) $@
	(cd $(STAGE_DIR) && tar czf ../$(PACKAGE) *)

%.zip: stage
	$(RM) $@
	(cd $(STAGE_DIR) && zip -j ../$(PACKAGE) *)

.PHONY: force
.compiler_flags: force
	@echo '$(CDEFS)' | cmp -s - $@ || echo '$(CDEFS)' > $@

$(OBJ): .compiler_flags

-include $(DEPS)
# vim: set ts=8:
