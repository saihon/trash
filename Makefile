NAME := tt
FILE := trash.sh
PREFIX := /usr/local/bin

$(NAME): clean
	@test -f $(FILE) && cp $(FILE) $(NAME) && chmod 755 $(NAME)

.PHONY: clean install uninstall

clean:
	@$(RM) $(NAME)

install:
	cp $(NAME) $(PREFIX)

uninstall:
	$(RM) -i $(PREFIX)/$(NAME)